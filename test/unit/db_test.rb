require 'test/test_helper'

context "DBTest: " do
  setup do
    def insert_message(db, documents)
      documents = [documents] unless documents.is_a?(Array)
      message = ByteBuffer.new
      message.put_int(0)
      BSON.serialize_cstr(message, "#{db.name}.test")
      documents.each { |doc| message.put_array(BSON.new.serialize(doc, true).to_a) }
      message = db.add_message_headers(Mongo::Constants::OP_INSERT, message)
    end
  end

  context "DB commands" do
    setup do
      @conn = stub()
      @db   = DB.new("testing", @conn)
      @collection = mock()
      @db.stubs(:system_command_collection).returns(@collection)
    end

    should "raise an error if given a hash with more than one key" do
      assert_raise MongoArgumentError do
        @db.command(:buildinfo => 1, :somekey => 1)
      end
    end

    should "raise an error if the selector is omitted" do
      assert_raise MongoArgumentError do
        @db.command({}, true)
      end
    end

    should "create the proper cursor" do
      @cursor = mock(:next_document => {"ok" => 1})
      Cursor.expects(:new).with(@collection, :admin => true,
        :limit => -1, :selector => {:buildinfo => 1}, :socket => nil).returns(@cursor)
      command = {:buildinfo => 1}
      @db.command(command, true)
    end

    should "raise an error when the command fails" do
      @cursor = mock(:next_document => {"ok" => 0})
      Cursor.expects(:new).with(@collection, :admin => true,
        :limit => -1, :selector => {:buildinfo => 1}, :socket => nil).returns(@cursor)
      assert_raise OperationFailure do
        command = {:buildinfo => 1}
        @db.command(command, true, true)
      end
    end

    should "raise an error if logging out fails" do
      @db.expects(:command).returns({})
      assert_raise MongoDBError do
        @db.logout
      end
    end

    should "raise an error if collection creation fails" do
      @db.expects(:collection_names).returns([])
      @db.expects(:command).returns({})
      assert_raise MongoDBError do
        @db.create_collection("foo")
      end
    end

    should "raise an error if getlasterror fails" do
      @db.expects(:command).returns({})
      assert_raise MongoDBError do
        @db.error
      end
    end

    should "raise an error if rename fails" do
      @db.expects(:command).returns({})
      assert_raise MongoDBError do
        @db.rename_collection("foo", "bar")
      end
    end

    should "raise an error if drop_index fails" do
      @db.expects(:command).returns({})
      assert_raise MongoDBError do
        @db.drop_index("foo", "bar")
      end
    end

    should "raise an error if set_profiling_level fails" do
      @db.expects(:command).returns({})
      assert_raise MongoDBError do
        @db.profiling_level = :slow_only
      end
    end
  end
end


